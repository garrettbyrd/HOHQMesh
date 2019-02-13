!
!////////////////////////////////////////////////////////////////////////
!
!      MeshOutputMethods.f95
!      Created: 2010-09-24 09:32:48 -0400 
!      By: David Kopriva  
!
!////////////////////////////////////////////////////////////////////////
!
      Module MeshOutputMethods
      USE MeshOperationsModule
      USE SMModelClass
      USE SMMeshObjectsModule
      IMPLICIT NONE
!
!     ========
      CONTAINS 
!     ========
!
!////////////////////////////////////////////////////////////////////////
!
      SUBROUTINE WriteToTecplot( mesh, fName ) 
         IMPLICIT NONE
!
!        ---------
!        Arguments
!        ---------
!
         TYPE( SMMesh )   :: mesh
         CHARACTER(LEN=*) :: fName
!
!        ---------------
!        Local Variables
!        ---------------
!
         INTEGER           :: iUnit, j
         INTEGER, EXTERNAL :: UnusedUnit
         
         CLASS(SMElement), POINTER :: e    => NULL()
         CLASS(FTObject) , POINTER :: obj  => NULL()
         CLASS(SMNode)   , POINTER :: node => NULL()
         INTEGER                   :: ids(8)
!
!        -----------
!        Open a file
!        -----------
!
         iUnit = UnusedUnit()
         OPEN( UNIT = iUnit, FILE = fName )
!
!        -------------
!        Set up header
!        -------------
!
         WRITE(iUnit,*) 'VARIABLES = "X", "Y", "Z", "Material ID"'
         WRITE(iUnit,*) 'ZONE F=FEPOINT, ET=QUADRILATERAL, N=',mesh % nodes % COUNT(), &
                        'E=',mesh % elements % COUNT()
!
!        ---------------
!        Write node data
!        ---------------
!
         CALL mesh % nodesIterator % setToStart()
         DO WHILE ( .NOT.mesh % nodesIterator % isAtEnd() )
            obj => mesh % nodesIterator % object()
            CALL castToSMNode(obj,node)
            WRITE( iUnit, *) node % x, node % materialID
            CALL mesh % nodesIterator % moveToNext()
         END DO
!
!        --------------------------
!        Write element connectivity
!        --------------------------
!
         CALL mesh % elementsIterator % setToStart()
         DO WHILE ( .NOT.mesh % elementsIterator % isAtEnd() )
            obj => mesh % elementsIterator % object()
            CALL castToSMelement(obj,e)
            DO j = 1, 4
               obj => e % nodes % objectAtIndex(j)
               CALL castToSMNode(obj, node)
               ids(j) = node % id
            END DO  
            WRITE( iUnit, *) (ids(j), j = 1, 4)
            CALL mesh % elementsIterator % moveToNext()
         END DO

         CLOSE( iUnit )
         
      END SUBROUTINE WriteToTecplot
!
!////////////////////////////////////////////////////////////////////////
!
      SUBROUTINE WriteISMMeshFile( mesh, fName, model, N, version )
         IMPLICIT NONE 
!
!        ---------
!        Arguments
!        ---------
!
         CLASS( SMMesh )   , POINTER :: mesh
         CLASS( SMModel)   , POINTER :: model
         CHARACTER(LEN=*)            :: fName
         INTEGER                     :: N       ! The polynomial order of the boundaries.
         INTEGER                     :: version !version number of the ISM format.
!
!        ---------------
!        Local Variables
!        ---------------
!
         CLASS(FTObject)    , POINTER         :: obj  => NULL()
         CLASS(SMNode)      , POINTER         :: node => NULL()
         CLASS(SMEdge)      , POINTER         :: edge => NULL()
         CLASS(SMElement)   , POINTER         :: e    => NULL()
         CLASS(FTLinkedListIterator), POINTER :: iterator => NULL()
         
         INTEGER                  :: iUnit, j, k
         INTEGER, DIMENSION(6)    :: edgeInfoArray
         INTEGER, EXTERNAL        :: UnusedUnit
!
!        ------------------------------------------
!        Get set up - ensure everything is in order
!        ------------------------------------------
!
         CALL mesh % renumberAllLists()
!
!        -----------
!        Open a file
!        -----------
!
         iUnit = UnusedUnit()
         OPEN( UNIT = iUnit, FILE = fName )
!!
!!        ----------------
!!        Print out header
!!        ----------------
!!
         IF ( version == ISM )     THEN
            WRITE(iUnit, *) mesh % nodes % COUNT(), mesh % elements % COUNT(), N
         ELSE IF( version == ISM2 )     THEN
            WRITE(iUnit,*) "ISM-V2"
            WRITE(iUnit, *) mesh % nodes % COUNT(), mesh % edges % COUNT(), mesh % elements % COUNT(), N
         ELSE IF( version == ISM_MM )     THEN
            WRITE(iUnit,*) "ISM-MM"
            WRITE(iUnit, *) mesh % nodes % COUNT(), mesh % edges % COUNT(), mesh % elements % COUNT(), N
         ELSE
            PRINT *, "Unknown file format type... mesh file not written"
            CLOSE( iUnit )
            RETURN
         END IF
!
!        -----------
!        Print Nodes
!        -----------
!
         iterator => mesh % nodesIterator
         CALL iterator % setToStart
         DO WHILE(.NOT.iterator % isAtEnd())
            obj => iterator % object()
            CALL cast(obj,node)
            WRITE(iUnit,*) node % x
            CALL iterator % moveToNext()
         END DO  
!
!        --------------------------------------------
!        In version 2, print out the edge information
!        --------------------------------------------
!
         IF( version == ISM2 )     THEN
!
!           ------------------------
!           Ensure edges are in sync
!           ------------------------
!
            CALL mesh % syncEdges()
!
!           --------------
!           Write them out
!           --------------
!
            iterator => mesh % edgesIterator
            CALL iterator % setToStart()
            DO WHILE(.NOT.iterator % isAtEnd())
               obj => iterator % object()
               CALL cast(obj,edge)
               CALL gatherEdgeInfo(edge, edgeInfoArray)
               WRITE(iUnit, '(6(I6,2x))') edgeInfoArray
               CALL iterator % moveToNext()
            END DO  
         END IF
!
!        ---------------------------------------------------------
!        Print element connectivity with boundary edge information
!        ---------------------------------------------------------
!
         iterator => mesh % elementsIterator
         CALL iterator % setToStart
         
         DO WHILE ( .NOT.iterator % isAtEnd() )
            obj => iterator % object()
            CALL cast(obj,e)
            
            IF ( version == ISM_MM )     THEN
               WRITE( iUnit, *) e % boundaryInfo % nodeIDs, TRIM(e % materialName)
            ELSE
               WRITE( iUnit, *) e % boundaryInfo % nodeIDs
            END IF
            
            WRITE( iUnit, *) e % boundaryInfo % bCurveFlag            
!
            DO k = 1, 4
               IF( e % boundaryInfo % bCurveFlag(k) == ON )     THEN
                  DO j = 0, N 
                     WRITE( iUnit, * ) e % boundaryInfo % x(:,j,k)
                  END DO
               END IF
            END DO
            
            WRITE( iUnit, *) (TRIM(e % boundaryInfo % bCurveName(k)), " ", k = 1, 4)
            
            CALL iterator % moveToNext()
         END DO
!         
      END SUBROUTINE WriteISMMeshFile
!
!////////////////////////////////////////////////////////////////////////
!
      SUBROUTINE gatherEdgeInfo( edge, info )
!
!     --------------------------------------------
!     Extract/Construct information about the edge
!
!     Info Returned:
!
!            info(1) = start node id
!            info(2) = end node id
!            info(3) = left element id
!            info(4) = right element id (or 0, if a boundary edge)
!            info(5) = element side for left element
!            info(6) = element side for right element signed for direction (or 0 for boundary edge)
!     
!     --------------------------------------------
!
         IMPLICIT NONE
!
!        ---------
!        Arguments
!        ---------
!
         CLASS(SMEdge), POINTER     :: edge
         INTEGER      , INTENT(OUT) :: info(6)
!
!        ---------------
!        Local Variables
!        ---------------
!
         INTEGER                  :: i, j
         INTEGER, DIMENSION(4,4)  :: s = RESHAPE((/-1,-1,1,1,-1,-1,1,1,1,1,-1,-1,1,1,-1,-1/),(/4,4/))
         
         IF( ASSOCIATED(edge % elements(2) % element ) )    THEN
            i = edge % elementSide(1)
            j = edge % elementSide(2)
            j = j*s(i,j)
            info(1) = edge % nodes(1)    % node % id
            info(2) = edge % nodes(2)    % node % id
            info(3) = edge % elements(1) % element % id
            info(4) = edge % elements(2) % element % id
            info(5) = i
            info(6) = j
         ELSE
            i = edge % elementSide(1)
            j = edge % elementSide(2)
            info(1) = edge % nodes(1)    % node % id
            info(2) = edge % nodes(2)    % node % id
            info(3) = edge % elements(1) % element % id
            info(4) = 0
            info(5) = i
            info(6) = 0
         END IF 
         
      END SUBROUTINE gatherEdgeInfo
      
      END Module MeshOutputMethods
      